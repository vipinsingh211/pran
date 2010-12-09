%%%-------------------------------------------------------------------
%%% File    : pran_sip.erl
%%% Author  : Anders Nygren <anders.nygren@gmail.com>
%%% Description : SIP decoder for PRAN.
%%%
%%% Created :  8 Dec 2010 by Anders Nygren <>
%%%-------------------------------------------------------------------
-module(pran_sip).

%% API
-export([decode/3]).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: 
%% Description:
%%--------------------------------------------------------------------
decode(Payload, Stack, _Opts) ->
    try rfc3261:decode('SIP-message',Payload) of
	{ok, PDU, <<>>} -> 
	    {[{sip,PDU}|Stack],<<>>,done};
	fail ->
	    Partial = partial_sip(erlang:binary_to_list(Payload)),
	    {[{sip,Partial}|Stack],<<>>,done}
    catch
	_:Reason ->
	    io:format("SIP failed ~p~n",[Reason]),
	    {[{sip_failed,Payload}|Stack],<<>>,done}
    end.

%%====================================================================
%% Internal functions
%%====================================================================
partial_sip(PDU) ->
    case rfc3261:decode('Request-Line',PDU) of
	{ok,RL,More} ->
	    {Hs,Rest} = get_headers(More,[]),
	    {'Request',RL,Hs,Rest};
	fail ->
	    case rfc3261:decode('Status-Line',PDU) of
		{ok,SL,More} ->
		    {Hs,Rest} = get_headers(More,[]),
		    {SL,Hs,Rest};
		fail ->
		    fail
	    end
    end.

get_headers(Bs,Acc) ->
    case rfc3261:decode('message-header',Bs) of
	{ok,H,More} ->
	    get_headers(More,[H|Acc]);
	fail ->
	    {lists:reverse(Acc),Bs}
    end.
