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

require_relative 'node';
require_relative 'utils';





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
	:job    => { :title => "Job",     :width => 20 },
	:source => { :title => "Source",  :width => 20 },
	:worker => { :title => "Worker",  :width => 20 },
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
	theColumns[:cpus] = theNode.cpus   + " x " + theNode.speed + "Ghz";
	theColumns[:mem]  = theNode.memory + "GB";
	theColumns[:load] = theNode.load;
	theColumns[:jobs] = "-";



	# Get the row
	theRow = "";

	NODE_COLUMNS.each_pair do |theKey, theInfo|
		theText  = theColumns[theKey].to_s;
		theWidth = theInfo[:width];
		
		theRow << theText.slice(0, theWidth-1).ljust(theWidth);
	end

	return(theRow);

end





#============================================================================
#		Status.showStatus : Show the status.
#----------------------------------------------------------------------------
def Status.showStatus(theGrid, theNodes)

	# Get the state we need
	if (theGrid.empty?)
		theGrid = "ygrid";
	end



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
	theHeader = headerColumns(JOB_COLUMNS);
	Utils.putHeader(theHeader, "-");

	puts "";
	puts "";

end





#==============================================================================
# Module
#------------------------------------------------------------------------------
end
