------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                        Copyright (C) 2012, AdaCore                       --
--                                                                          --
--  This is free software;  you can redistribute it  and/or modify it       --
--  under terms of the  GNU General Public License as published  by the     --
--  Free Software  Foundation;  either version 3,  or (at your option) any  --
--  later version.  This software is distributed in the hope  that it will  --
--  be useful, but WITHOUT ANY WARRANTY;  without even the implied warranty --
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU     --
--  General Public License for  more details.                               --
--                                                                          --
--  You should have  received  a copy of the GNU General  Public  License   --
--  distributed  with  this  software;   see  file COPYING3.  If not, go    --
--  to http://www.gnu.org/licenses for a complete copy of the license.      --
------------------------------------------------------------------------------

with Ada.Streams;

with AWS.Net.Log;
with AWS.Response;
with AWS.Status;

with AWS.Net.WebSocket;

package WebSock_CB is

   use Ada.Streams;
   use AWS;

   procedure W_log
     (Direction : Net.Log.Data_Direction;
      Socket    : Net.Socket_Type'Class;
      Data      : Stream_Element_Array;
      Last      : Stream_Element_Offset);

   --  My WebSocket, just display the messages

   type Update_Websoket is new Net.WebSocket.Object with private;

   function Websocket_Factory
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class;

   overriding procedure On_Message (Socket : in out Update_Websoket; Message : String);
   --  Message received from the server

   overriding procedure On_Open (Socket : in out Update_Websoket; Message : String);
   --  Open event received from the server

   overriding procedure On_Close (Socket : in out Update_Websoket; Message : String);
   --  Close event received from the server

   overriding procedure Send (Socket : in out Update_Websoket; Message : String);
   --  Send a message to the server

   procedure Set_Quartiere (This: in out Update_Websoket; Q : Natural);
   function Get_Quartiere (This: in Update_Websoket) return Natural;

private

   type Update_Websoket is new Net.WebSocket.Object with record
     C : Natural := 0;
   end record
;
end WebSock_CB;
