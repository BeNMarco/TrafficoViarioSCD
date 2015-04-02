with Ada.Text_IO;
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
begin
   num_quartieri:= 3;
   configure_num_quartieri_name_server(num_quartieri);
   Put_Line(IOR);
   Create(File => IOR_File, Mode => Out_File, Name => "ior.txt");
   Put_Line(IOR_File, IOR);
   Close(IOR_File);

   loop
      delay 1.0;
      begin
         for i in 1..num_quartieri loop
            if get_ref_quartiere(i)/=null then
               if get_ref_quartiere(i).is_a_new_quartiere(1) then
                  null;
               end if;
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
            -- notifica agli altri quartieri la chiusura
            -- per evitare che restino bloccati in wait
            return;
      end;
      exit when False;
   end loop;
exception
   when others =>
      null;
end;
