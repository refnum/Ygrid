#!/usr/bin/ruby -w
#==============================================================================
#	NAME:
#		job.rb
#
#	DESCRIPTION:
#		Job object.
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
# Class
#------------------------------------------------------------------------------
class Job


# Attributes
attr_accessor :grid
attr_accessor :host
attr_accessor :src_host
attr_accessor :src_index
attr_accessor :cmd_task
attr_accessor :cmd_done
attr_accessor :files_input
attr_accessor :files_output
attr_accessor :weight_local
attr_accessor :weight_cpu
attr_accessor :weight_mem


# Defaults
DEFAULT_GRID			= "";
DEFAULT_HOST			= nil;
DEFAULT_SRC_HOST		= nil;
DEFAULT_SRC_INDEX		= nil;
DEFAULT_CMD_TASK		= "";
DEFAULT_CMD_DONE		= "";
DEFAULT_FILES_INPUT		= [];
DEFAULT_FILES_OUTPUT	= [];
DEFAULT_WEIGHT_LOCAL	= 10.0;
DEFAULT_WEIGHT_CPU		= 1.0;
DEFAULT_WEIGHT_MEM		= 1.0;





#==============================================================================
#		Job::initialize : Initialiser.
#------------------------------------------------------------------------------
def initialize(thePath)

	# Load the file
	load(thePath);

end





#============================================================================
#		Job::validate : Validate a job.
#----------------------------------------------------------------------------
def validate

	# Validate the job
	theErrors = [];
	
	if (@cmd_task.empty?)
		theErrors << "job does not contain 'cmd_task'";
	end

	return(theErrors);

end





#==============================================================================
#		Job::load : Load a job.
#------------------------------------------------------------------------------
def load(thePath)

	# Load the job
	theInfo = JSON.parse(IO.read(thePath), {:symbolize_names => true});

	@grid			= theInfo.fetch(:grid,			DEFAULT_GRID);
	@host			= theInfo.fetch(:host,			DEFAULT_HOST);
	@src_host		= theInfo.fetch(:src_host,		DEFAULT_SRC_HOST);
	@src_index		= theInfo.fetch(:src_index,		DEFAULT_SRC_INDEX);
	@cmd_task		= theInfo.fetch(:cmd_task,		DEFAULT_CMD_TASK);
	@cmd_done		= theInfo.fetch(:cmd_done,		DEFAULT_CMD_DONE);
	@files_input	= theInfo.fetch(:files_input,	DEFAULT_FILES_INPUT);
	@files_output	= theInfo.fetch(:files_output,	DEFAULT_FILES_OUTPUT);
	@weight_local	= theInfo.fetch(:weight_local,	DEFAULT_WEIGHT_LOCAL);
	@weight_cpu		= theInfo.fetch(:weight_cpu,	DEFAULT_WEIGHT_CPU);
	@weight_mem		= theInfo.fetch(:weight_mem,	DEFAULT_WEIGHT_MEM);



	# Convert the addresses
	@host      = IPAddr.new(@host)     if (@host     != nil);
	@src_host  = IPAddr.new(@src_host) if (@src_host != nil);

end





#============================================================================
#		Job::save : Save a job.
#----------------------------------------------------------------------------
def save(theFile)

	# Get the state we need
	tmpFile = theFile + "_tmp";
	theInfo = Hash.new();

	theInfo[:grid]			= @grid				if (@grid			!= DEFAULT_GRID);
	theInfo[:host]			= @host				if (@host			!= DEFAULT_HOST);
	theInfo[:src_host]		= @src_host			if (@src_host		!= DEFAULT_SRC_HOST);
	theInfo[:src_index]		= @src_index		if (@src_index		!= DEFAULT_SRC_INDEX);
	theInfo[:cmd_task]		= @cmd_task			if (@cmd_task		!= DEFAULT_CMD_TASK);
	theInfo[:cmd_done]		= @cmd_done			if (@cmd_done		!= DEFAULT_CMD_DONE);
	theInfo[:files_input]	= @files_input		if (@files_input	!= DEFAULT_FILES_INPUT);
	theInfo[:files_output]	= @files_output		if (@files_output	!= DEFAULT_FILES_OUTPUT);
	theInfo[:weight_local]	= @weight_local		if (@weight_local	!= DEFAULT_WEIGHT_LOCAL);
	theInfo[:weight_cpu]	= @weight_cpu		if (@weight_cpu		!= DEFAULT_WEIGHT_CPU);
	theInfo[:weight_mem]	= @weight_mem		if (@weight_mem		!= DEFAULT_WEIGHT_MEM);



	# Save the file
	#
	# To ensure the write is atomic we save to a temporary and then rename.
	IO.write(    tmpFile, JSON.pretty_generate(theInfo) + "\n");
	FileUtils.mv(tmpFile, theFile);

end





#============================================================================
#		Job::id : Get the job ID.
#----------------------------------------------------------------------------
def id

	return(Job.encodeID(@src_index, @src_host));

end





#============================================================================
#		Job.encodeID : Encode an ID.
#----------------------------------------------------------------------------
def self.encodeID(theIndex, theAddress)

	# Encode the ID
	#
	# A job ID is a unique 16-character identifier that contains a
	# node-specific index and the IP address of the source node.
	theID = "%08X%08X" % [theIndex, theAddress.to_i];

	return(theID);

end





#============================================================================
#		Job.decodeID : Decode an ID.
#----------------------------------------------------------------------------
def self.decodeID(jobID)

	# Decode the ID
	theIndex   = jobID.slice( 0, 8).hex;
	theAddress = IPAddr.new(jobID.slice(-8, 8).hex, Socket::AF_INET);
	theInfo    = { :src_index => theIndex, :src_host => theAddress };

	return(theInfo);

end





#==============================================================================
# Class
#------------------------------------------------------------------------------
end
