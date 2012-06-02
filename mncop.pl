#!/usr/bin/perl
#
#
# mncop.pl
#
# multi network connect and operup perform
# 
# allow specific commands
# "on connect" and "on operup"
#
# place files in ~/.xchat2
#
# Copyright (C) 2003 Gregor Jehle <gjehl@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
#
# HISTORY
#
# 2nd JUN 2012
# MIT license
# released to GitHub
#
# 2nd SEP 2005
# added support for post-qauth rules
#

package MnCOP;

my $VERSION  = 1.0;
my $NAME     = 'multinet con/op perform';

IRC::register("$NAME","$VERSION","","");
IRC::add_command_handler('mncop_rehash','MnCOP::_rehash_config');
IRC::add_message_handler('376','MnCOP::_handle_connect');
IRC::add_message_handler('RPL_ENDOFMOTD','MnCOP::_handle_connect');
IRC::add_message_handler('381','MnCOP::_handle_operup');
IRC::add_message_handler('RPL_YOUREOPER','MnCOP::_handle_operup');
IRC::add_message_handler('366','MnCOP::_handle_join');
IRC::add_message_handler('NOTICE','MnCOP::_handle_notice');

my $xchatdir = IRC::get_info(4);
my $config   = 'mncop_perform.conf';
my %CFG      = ();

&_echo("loaded $NAME version $VERSION");
&_rehash_config();

sub _rehash_config
{

	my $cnet = '-base';
	   %CFG  = ();
	   
	&_echo("(RE)HASHING CONFIG FILE!");

	if (!-e "$xchatdir/$config")
	{
		&_echo("WARNING: no config file in $xchatdir/$config !");
	}
	else
	{
		if( open(CFG,"<$xchatdir/$config") )
		{
			while(<CFG>)
			{
				if(/^[^#]/)
				{
					if(/^\[([^\]]+)\]/)
					{
						$cnet=lc("$1");
					}
					elsif(/^enable=(1|0)/i)
					{
						$CFG{"$cnet"}{'enable'}=$1;
					}
					elsif(/^connect=(.+)/)
					{
						push @{$CFG{"$cnet"}{'c'}}, "$1";
					}
					elsif(/^operup=(.+)/)
					{
						push @{$CFG{"$cnet"}{'o'}}, "$1";
					}
					elsif(/^postqauth=(.+)/)
					{
						push @{$CFG{"$cnet"}{'q'}}, "$1";
					}
					elsif(/^join_(\#[^=]+)=(.+)/)
					{
						push @{$CFG{"$cnet"}{'j'}{"$1"}}, "$2";
					}
					elsif($_ ne "\n" && $_ ne "")
					{
						&_echo("error parsing line $. : $_");
					}
				}
			}
			close(CFG);
			&_echo("loaded config")
		}
		else
		{
			&_echo("unable to open $xchatdir/$config : $!");
		}
	}
1;
}


sub _handle_connect
{
	my $net = lc(IRC::get_info(6));
	my $nick = IRC::get_info(1);
	if($CFG{"$net"}{'enable'})
	{
		&_echo("found active connect perform rules for network $net");
		foreach(@{$CFG{"$net"}{'c'}})
		{
			s/\%self\%/$nick/g;
			IRC::send_raw("$_");
		}
	}
	else
	{
		&_echo("no connect perform rules active or set for network $net");
	}
0;
}

sub _handle_operup
{
	my $net = lc(IRC::get_info(6));
	my $nick = IRC::get_info(1);
	if($CFG{"$net"}{'enable'})
	{
		&_echo("found active oper perform rules for network $net");
		foreach(@{$CFG{"$net"}{'o'}})
		{
			s/\%self\%/$nick/;
			IRC::send_raw("$_");
		}
	}
	else
	{
		&_echo("no oper perform rules active or set for network $net");
	}
0;
}

sub _handle_join
{
#:hAD3z!~hadez@xxxxxxxxxx.dip.t-dialin.net JOIN :#mircryption
	my $net = lc(IRC::get_info(6));
	my $nick = IRC::get_info(1);
	my $line = join(" ",@_);
	   $line =~ s/\s+/ /g;
	my @line = split /\s/, $line;
	my $chan = ($line[2]=~/^:(.+?)/);

	return 0 if($line[0] !~ /^:$nick!/);

	if($CFG{"$net"}{'enable'})
	{
		&_echo("found active join perform rules for $channel/$net");
		foreach(@{$CFG{"$net"}{'j'}{"$chan"}})
		{
			s/\%self\%/$nick/;
			s/\%chan\%/$chan/;
			IRC::send_raw("$_");
		}
	}
0;
}

sub _handle_notice
{
	my $line = join(" ",@_);
       $line =~ s/\s+/ /g;
	my $nick = IRC::get_info(1);

	#:Q!TheQBot@CServe.quakenet.org NOTICE iND-MePh :AUTH'd successfully.
	return 0 if($line !~ /^:Q!TheQBot\@CServe\.quakenet\.org\sNOTICE\s\S+\s:AUTH\'d successfully\./);

    if($CFG{"$net"}{'enable'})
    {
		&_echo("found active post-qauth rules for network $net");
    	foreach(@{$CFG{"$net"}{'q'}})
        {
           	s/\%self\%/$nick/;
	        IRC::send_raw("$_");
    	}
    }

0;
}
sub _echo
{
	IRC::print("MnCOP $_[0]");
}

