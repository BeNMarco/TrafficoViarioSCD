with Ada.Text_IO;
with Ada.Command_Line;
with PolyORB.Parameters;
with the_name_server;
with remote_types;
with strade_e_incroci_common;

use the_name_server;
use remote_types;
use strade_e_incroci_common;
use Ada.Text_IO;

procedure rci_utilities is
   IOR : String:= PolyORB.Parameters.Get_Conf ("dsa", "name_service", "");
   IOR_File : File_Type;
   num_quartieri: Positive;
   errore: Boolean:= False;

   task wait_quit_signal;

   task body wait_quit_signal is
      --line: String(1..4);
      --last: Natural;
      c: Character;
      closing: Boolean:= False;
      available: Boolean:= False;
   begin
      loop
         delay 2.0;
         available:= False;
         Get_Immediate(c,available);
         if errore=False and then (available and then (c='q' or c='Q')) then
            quit_signal; -- invia al nameserver il segnale di chiusura
            closing:= True;
            New_Line(1);
            Put_Line("Il sistema si sta chiudendo... ... ...");
         --elsif errore=False and then available then
         --   New_Line(1);
         end if;
         exit when (closing or errore) or signal_quit_arrived;
      end loop;
   end wait_quit_signal;

begin
   num_quartieri:= 3;
   configure_num_quartieri_name_server(num_quartieri);
   Put_Line(IOR);
   Create(File => IOR_File, Mode => Out_File, Name => "ior.txt");
   Put_Line(IOR_File, IOR);
   Close(IOR_File);

   Put_Line("Digitare q or Q per chiudere il sistema.");
   loop
      delay 1.0;
      begin
         for i in 1..num_quartieri loop
            if get_ref_quartiere(i)/=null then
               begin
                  if get_ref_quartiere(i).is_a_new_quartiere(1) then
                     null;
                  end if;
               exception
                  when others =>
                     if has_quartiere_finish_all_operations(i) then
                        null;
                     else
                        raise;
                     end if;
               end;
            end if;
         end loop;
         if get_server_gps/=null and then get_server_gps.is_alive then
            null;
         end if;
         if get_webServer/=null and then get_webServer.is_alive then
            null;
         end if;
      exception
         when others =>
            errore:= True;
            Put_Line("partizione remota non raggiungibile.");
            --Put_Line("premevere invio per chiudere.");
            return;
      end;
      exit when (all_quartieri_has_finish_operations or
        (signal_quit_arrived and get_num_quartieri_up=0));
   end loop;
   Put_Line("Tutti i quartieri sono stati chiusi.");

   -- chiudi server
   if get_server_gps/=null then
      get_server_gps.close_gps;
   end if;
   loop
      delay 1.0;
      begin
         if get_server_gps/=null and then get_server_gps.is_alive then
            null;
         end if;
      exception
         when others =>
            if server_is_closed then
               null;
            else
               raise;
            end if;
      end;
      exit when (server_is_closed or
        (signal_quit_arrived and get_server_gps=null));
   end loop;
   Put_Line("Server chiuso.");

   -- chiudi webserver
   --if get_webServer/=null then
      --get_webServer.close_webserver;
   --end if;
   --loop
   --   delay 1.0;
   --   begin
   --      if get_webServer/=null and then get_webServer.is_alive then
   --         null;
   --      end if;
   --   exception
   --      when others =>
   --         if web_server_is_closed then
   --            null;
   --         else
   --            raise;
   --         end if;
   --   end;
   --   exit when web_server_is_closed or
   --     (signal_quit_arrived and get_webServer=null));
   --end loop;
   --Put_Line("Il web server è stato chiuso.");

exception
   when others =>
      errore:= True;
      Put_Line("Partizione remota non raggiungibile.");
      --Put_Line("premevere invio per chiudere.");
end;
