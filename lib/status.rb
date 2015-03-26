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

require_relative 'agent';
require_relative 'job';
require_relative 'node';





#==============================================================================
# Module
#------------------------------------------------------------------------------
module Status

NODE_COLUMNS = {
	:name => { :title => "Node",      :width => 25 },
	:addr => { :title => "Address",   :width => 18 },
	:cpus => { :title => "CPUs",      :width => 15 },
	:mem  => { :title => "Memory",    :width => 14 },
	:load => { :title => "Load",      :width => 10 },
	:jobs => { :title => "Jobs",      :width => 4  }
};

JOB_COLUMNS = {
	:id     => { :title => "Job",     :width => 20 },
	:source => { :title => "Source",  :width => 20 },
	:worker => { :title => "Worker",  :width => 20 },
	:time   => { :title => "Time",    :width => 14 },
	:status => { :title => "Status",  :width => 8  },
};





#============================================================================
#		Status.headerColumns : Get a header.
#----------------------------------------------------------------------------
def Status.headerColumns(theInfo)

	# Get the header
	theHeader = "";

	theInfo.each_value do |theColumn|
		theText   = theColumn[:title];
		theWidth  = theColumn[:width];
		theHeader << theText.ljust(theWidth);
	end

	return(theHeader);

end





#============================================================================
#		Status.nodeRow : Get a node table row.
#----------------------------------------------------------------------------
def Status.nodeRow(theNode)

	# Build the columns
	theColumns = Hash.new();

	theColumns[:name] = theNode.pretty_name;
	theColumns[:addr] = theNode.address;
	theColumns[:cpus] = theNode.cpus.to_s   + " x " + theNode.speed.to_s + "Ghz";
	theColumns[:mem]  = theNode.memory.to_s + "GB";
	theColumns[:load] = theNode.load;
	theColumns[:jobs] = theNode.jobs;



	# Get the row
	theRow = "";

	NODE_COLUMNS.each_pair do |theColumn, columnInfo|
		theText  = theColumns[theColumn].to_s;
		theWidth = columnInfo[:width];
		
		theRow << theText.slice(0, theWidth-1).ljust(theWidth);
	end

	return(theRow);

end





#============================================================================
#		Status.jobRow : Get a job table row.
#----------------------------------------------------------------------------
def Status.jobRow(jobID, theInfo)

	# Build the columns
	theColumns = Hash.new();

	theColumns[:id]     = jobID;
	theColumns[:source] = theInfo[:source];
	theColumns[:worker] = theInfo[:worker];
	theColumns[:time]   = theInfo[:time];

	case theInfo[:status]
		when Agent::PROGRESS_ACTIVE
			theColumns[:status] = "Active";

		when Agent::PROGRESS_DONE
			theColumns[:status] = "Done";

		else
			theColumns[:status] = theInfo[:status] + "%";
	end



	# Get the row
	theRow = "";

	JOB_COLUMNS.each_pair do |theColumn, columnInfo|
		theText  = theColumns[theColumn].to_s;
		theWidth = columnInfo[:width];

		theRow << theText.slice(0, theWidth-1).ljust(theWidth);
	end

	return(theRow);

end





#============================================================================
#		Status.collectJobs : Collect the jobs for a grid.
#----------------------------------------------------------------------------
def Status.collectJobs(theGrid, theNodes)

	# Get the state we need
	theJobs = Hash.new();



	# Collect the jobs
	theNodes.each do |theNode|
		theStatus = Agent.callServer(theNode.address, "currentStatus");
		theStatus[:active].each_pair do |jobID, theInfo|

			if (theInfo[:grid] == theGrid)
				# Calculate the time
				timeStart = theInfo[:time_start];
				timeEnd   = theInfo.fetch(:time_end, Time.now);

				theTime = timeEnd - timeStart;
				theTime = Time.at(theTime).utc.strftime("%H:%M:%S");



				# Save the job
				theInfo = theInfo.dup();

				theInfo[:source] = Job.decodeID(jobID)[:src_host];
				theInfo[:worker] = theNode.address;
				theInfo[:time]   = theTime;

				theJobs[jobID] = theInfo;
			end

		end
	end

	return(theJobs);

end





#============================================================================
#		Status.showStatus : Show the status.
#----------------------------------------------------------------------------
def Status.showStatus(theGrid, theNodes)

	# Get the state we need
	theJobs = collectJobs(theGrid, theNodes);
	theGrid = "ygrid" if (theGrid.empty?)



	# Show the header
	Utils.putHeader(theGrid, "=");



	# Show the nodes
	theHeader = headerColumns(NODE_COLUMNS);
	Utils.putHeader(theHeader, "-");

	theNodes.each do |theNode|
		puts nodeRow(theNode);
	end

	puts "";
	puts "";



	# Show the jobs
	if (!theJobs.empty?)
		theHeader = headerColumns(JOB_COLUMNS);
		Utils.putHeader(theHeader, "-");
	
		theJobs.each_pair do |jobID, theInfo|
			puts jobRow(jobID, theInfo);
		end

		puts "";
		puts "";
	end

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
