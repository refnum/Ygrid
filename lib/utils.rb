#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		utils.rb
#
#	DESCRIPTION:
#		Utility code.
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
require 'optparse'
require 'rbconfig';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Utils





#============================================================================
#		Utils.hostOS : Get the host OS.
#----------------------------------------------------------------------------
def Utils.hostOS

	case RbConfig::CONFIG['host_os']
		when /darwin|mac os/
			return("mac");
		
		when /linux/
			return("linux");

		when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
			return("windows");
	end

	return("UNKNOWN");

end





#============================================================================
#		Utils.cpuCount : Get the number of CPUs.
#----------------------------------------------------------------------------
def Utils.cpuCount

	case Utils.hostOS()
		when "mac", "linux"
			return(`sysctl -n hw.ncpu`.chomp);
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Utils.cpuGHz : Get the CPU speed.
#----------------------------------------------------------------------------
def Utils.cpuGHz

	case Utils.hostOS()
		when "mac", "linux"
			return((`sysctl -n hw.cpufrequency`.chomp.to_f / 1000000000.0).to_s);
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Utils.memGB : Get the physical memory.
#----------------------------------------------------------------------------
def Utils.memGB

	case Utils.hostOS()
		when "mac", "linux"
			return((`sysctl -n hw.memsize`.chomp.to_i / 1073741824).to_s);
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Utils.sysLoad : Get the system load.
#----------------------------------------------------------------------------
def Utils.sysLoad

	case Utils.hostOS()
		when "mac", "linux"
			loadTotal = `sysctl -n vm.loadavg | cut -f 2 -d ' '`.chomp.to_f;
			numCPUs   = cpuCount().to_f;

			return("%.2f" % (loadTotal / numCPUs));
	end

	abort("UNKNOWN PLATFORM");

end





#============================================================================
#		Utils.getCount : Get a count.
#----------------------------------------------------------------------------
def Utils.getCount(theArray, theSingular, thePlural=nil)

	if (thePlural == nil)
		thePlural = theSingular + "s";
	end
	
	return(theArray.size.to_s + " " + (theArray.size == 1 ? theSingular : thePlural));

end





#============================================================================
#		Utils.putHeader : Display a header.
#----------------------------------------------------------------------------
def Utils.putHeader(theHeader, theDivider)

	puts theHeader;
	puts theDivider * theHeader.size;

end





#============================================================================
#		Utils.cmdInstalled? : Is a command installed?
#----------------------------------------------------------------------------
def Utils.cmdInstalled?(theCmd)

	return(`which #{theCmd} | wc -c`.to_i != 0);

end





#============================================================================
#		Utils.cmdRunning? : Is a command running?
#----------------------------------------------------------------------------
def Utils.cmdRunning?(pidFile)

	if (File.exists?(pidFile))
		thePID    = IO.read(pidFile).to_i;
		isRunning = system("ps -p #{thePID} > /dev/null");
	else
		isRunning = false;
	end
	
	return(isRunning);

end





#============================================================================
#		Utils.checkInstall : Check the installation.
#----------------------------------------------------------------------------
def Utils.checkInstall

	# Get the state we need
	haveRsync = cmdInstalled?("rsync");
	haveSerf  = cmdInstalled?("serf");



	# Show some help
	case Utils.hostOS()
		when "mac"
			if (!haveSerf)
				puts "Unable to locate serf. Install with Homebrew:";
				puts "";
				puts"   # http://brew.sh/";
				puts "  brew install caskroom/cask/brew-cask";
				puts "  brew cask install serf";
				puts "";
			end
		
		
		when "linux"
			if (!haveRsync)
				puts "Unable to locate rsync. Install with 'apt-get install rsync'";
				puts "";
			end

			if (!haveSerf)
				puts "Unable to locate serf. Install from https://www.serfdom.io/downloads.html";
				puts "";
			end
		
		
		else
			puts "UNKNOWN PLATFORM";
	end



	# Handle failure
	if (!haveRsync || !haveSerf)
		exit(-1);
	end

end





#============================================================================
#		Utils.getArguments : Get the arguments.
#----------------------------------------------------------------------------
def Utils.getArguments

	# Extract the options
	theArgs   = Hash.new("");
	theParser = OptionParser.new do |opts|
		opts.on("-r", "--root=path") do |thePath|
			theArgs["root"] = thePath;
		end

		opts.on("-g", "--grid=grid1,grid2,gridN") do |theGrid|
			theArgs["grid"] = theGrid;
		end
	end;

	theParser.parse!;



	# Extract the arguments
	theArgs["cmd"] = "help";

	if (!ARGV.empty?)
		theArgs["cmd"]  = ARGV.shift;
		theArgs["args"] = ARGV;
	end



	# Validate the arguments
	case theArgs["cmd"]
		when "start"
			if (theArgs["root"].empty?)
				theArgs["cmd"] = "help";
			end
		
		when "join", "leave"
			if (theArgs["grid"].empty?)
				theArgs["cmd"] = "help";
			end
	end
	
	return(theArgs);

end





#============================================================================
#		Utils.sleepLoop : Loop and sleep.
#----------------------------------------------------------------------------
def Utils.sleepLoop(theTime, &block)

	# Loop until Ctrl-C
	begin
		loop do
			block.call();
			sleep(theTime);
		end

	rescue Interrupt
		# Consume the stack crawl

	rescue Exception => e
		puts e
	end

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
