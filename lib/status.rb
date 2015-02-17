#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		Status.rb
#
#	DESCRIPTION:
#		Status module.
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

require_relative 'utils';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Status

WORKER_COLUMNS = {
	"name" => { "title" => "Worker",     "width" => 25 },
	"host" => { "title" => "IP Address", "width" => 18 },
	"cpus" => { "title" => "CPUs",       "width" => 15 },
	"mem"  => { "title" => "Memory",     "width" => 14 },
	"load" => { "title" => "Load",       "width" => 10 },
	"jobs" => { "title" => "Jobs",       "width" => 4  }
};

JOB_COLUMNS = {
	"job"    => { "title" => "Job",     "width" => 20 },
	"source" => { "title" => "Source",  "width" => 20 },
	"worker" => { "title" => "Worker",  "width" => 20 },
	"status" => { "title" => "Status",  "width" => 6  },
};





#============================================================================
#		Status.headerColumns : Get a header.
#----------------------------------------------------------------------------
def Status.headerColumns(theInfo)

	# Get the header
	theHeader = "";

	theInfo.each_value do |theColumn|
		theText   = theColumn["title"];
		theWidth  = theColumn["width"];
		theHeader << theText.ljust(theWidth);
	end

	return(theHeader);

end





#============================================================================
#		Status.workerRow : Get a worker table row.
#----------------------------------------------------------------------------
def Status.workerRow(theWorker)

	# Build the columns
	theTags    = theWorker["tags"];
	theColumns = Hash.new();

	theColumns["name"] = theWorker["name"].sub(/.local$/, "");
	theColumns["host"] = theWorker["addr"].split(":").first;
	theColumns["load"] = theTags["load"];
	theColumns["jobs"] = "-";
	theColumns["cpus"] = theTags["cpu"] + " x " + theTags["ghz"] + "Ghz";
	theColumns["mem"]  = theTags["mem"] + "GB";



	# Get the row
	theRow = "";

	WORKER_COLUMNS.each_pair do |theKey, theInfo|
		theText  = theColumns[theKey];
		theWidth = theInfo["width"];
		theRow   << theText.slice(0, theWidth-1).ljust(theWidth);
	end

	return(theRow);

end





#============================================================================
#		Status.putStdout : Send the status to stdout.
#----------------------------------------------------------------------------
def Status.putStdout(theGrid, theStatus)

	# Get the state we need
	theMembers = theStatus["members"];
	
	if (theGrid.empty?)
		theGrid = "ygrid";
	end



	# Show the header
	Utils.putHeader(theGrid, "=");



	# Show the workers
	theHeader = headerColumns(WORKER_COLUMNS);
	Utils.putHeader(theHeader, "-");

	theMembers.each do |theWorker|
		puts workerRow(theWorker);
	end

	puts "";
	puts "";



	# Show the jobs
	theHeader = headerColumns(JOB_COLUMNS);
	Utils.putHeader(theHeader, "-");

	puts "";
	puts "";

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
