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

with Ada.Characters.Handling;
with Ada.Integer_Text_IO;
with Ada.Text_IO;
with Ada.Strings.Equal_Case_Insensitive;

with AWS.Messages;
with AWS.MIME;
with AWS.Templates;
with AWS.Translator;
with GNATCOLL.JSON; use GNATCOLL.JSON;

with Ada.Calendar; use Ada.Calendar;
with the_name_server; use the_name_server;
with Districts_Repository; use Districts_Repository;

with WebServer; use WebServer;

package body WebSock_Mainpage_CB is


   use Ada;
   use type AWS.Net.WebSocket.Kind_Type;
   use AWS;

   WWW_Root : constant String := "web_elements";

   ------------
   -- Create --
   ------------

   function Websocket_Factory
     (Socket  : Net.Socket_Access;
      Request : Status.Data) return Net.WebSocket.Object'Class is
   begin
      Text_IO.Put_Line("Created websocket " & Status.URI(Request));
      return Update_Websoket'(Net.WebSocket.Object
                       (Net.WebSocket.Create (Socket, Request)) with C => 0);
   end Websocket_Factory;

   procedure Send_District_Activated (Socket : in out Update_Websoket; District : Natural) is
      JData : JSON_Value := Create_Object;
   begin
      Set_Field(Val => JData, Field_Name => "type", Field => "update");
      Set_Field(Val => JData, Field_Name => "quartiere", Field => District);
      Net.WebSocket.Object (Socket).Send (Write(JData));
   end Send_District_Activated;

   --------------
   -- On_Close --
   --------------

   overriding procedure On_Close (Socket : in out Update_Websoket; Message : String) is
   begin
      Text_IO.Put_Line
        ("Received : Connection_Close "
         & Net.WebSocket.Error_Type'Image (Socket.Error) & ", " & Message);
   end On_Close;

   ----------------
   -- On_Message --
   ----------------

   overriding procedure On_Message
     (Socket : in out Update_Websoket; Message : String) is

     function eqic(Left, Right : String) return Boolean renames Ada.Strings.Equal_Case_Insensitive;

     JMessage : JSON_Value := Read(Strm => Message,
                                 Filename => "debug.txt");     
   begin
      if Has_Field(JMessage, "type") and eqic(Get(JMessage, "type"), "command") then
         -- received a command message from the client
         if eqic(Get(JMessage, "command"), "terminate") then
            WebServer.get_webserver.notifica_richiesta_terminazione;
            delay until (Clock + 1.0);
            the_name_server.quit_signal;
         end if;
      end if;
      
      --WebServer.set_richiesta_terminazione(True);
   end On_Message;

   -------------
   -- On_Open --
   -------------

   overriding procedure On_Open (Socket : in out Update_Websoket; Message : String) is
      R : Districts_Registry_Type := WebServer.get_webserver.Get_Districts_Registry;
   begin
      for I in R'Range loop
         if R(I).Is_Initialized then
            Send_District_Activated(Socket, I);
         end if;
      end loop;
      Text_IO.Put_Line("Web Socket opened " & Message);
   end On_Open;

   ----------
   -- Send --
   ----------

   -- overriding procedure Send (Socket : in out Update_Websoket; Message : String) is
   -- begin
      -- Text_IO.Put_Line("Sending "&Message);
      -- Net.WebSocket.Object (Socket).Send (Message);
   -- send Send;

end WebSock_Mainpage_CB;

