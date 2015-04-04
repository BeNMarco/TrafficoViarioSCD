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

with AWS.Messages;
with AWS.MIME;
with AWS.Templates;
with AWS.Translator;
with GNATCOLL.JSON; use GNATCOLL.JSON;

with WebServer; use WebServer;

package body WebSock_CB is

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
   begin
      Text_IO.Put_Line ("Received : " & Message);

      --WebServer.set_richiesta_terminazione(True);
   end On_Message;

   -------------
   -- On_Open --
   -------------

   overriding procedure On_Open (Socket : in out Update_Websoket; Message : String) is
   begin
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

   procedure Set_Quartiere (This: in out Update_Websoket; Q : Natural) is
   begin
      This.C := Q;
   end Set_Quartiere;

   function Get_Quartiere (This: in Update_Websoket) return Natural is
   begin
      return This.C;
   end Get_Quartiere;

   -----------
   -- W_Log --
   -----------

   procedure W_log
     (Direction : Net.Log.Data_Direction;
      Socket    : Net.Socket_Type'Class;
      Data      : Stream_Element_Array;
      Last      : Stream_Element_Offset)
   is
      Max : constant := 6;
      Str : String (1 .. Max);
      I   : Natural := Str'First - 1;
   begin
      Text_IO.Put_Line (Net.Log.Data_Direction'Image (Direction));
      Text_IO.Put_Line ("[");

      for K in Data'First .. Last loop
         I := I + 1;
         if Characters.Handling.Is_Graphic (Character'Val (Data (K))) then
            Str (I) := Character'Val (Data (K));
         else
            Str (I) := '.';
         end if;

         Text_IO.Put (Str (I));

         Text_IO.Put ('|');
         Integer_Text_IO.Put (Integer (Data (K)), Base => 16, Width => 6);
         Text_IO.Put ("   ");

         if K mod Max = 0 then
            Text_IO.Put_Line (" " & Str (Str'First .. I));
            I := Str'First - 1;
         end if;
      end loop;

      if I > Str'First then
         Text_IO.Set_Col (67);
         Text_IO.Put_Line (" " & Str (Str'First .. I));
      end if;

      Text_IO.Put_Line ("]");
   end W_Log;

end WebSock_CB;
