with Ada.Text_IO;

with PolyORB.Parameters;

use Ada.Text_IO;

--with global_data;
with the_name_server;
with configuration_synchronized_package;

use the_name_server;
use configuration_synchronized_package;
--use global_data;

procedure rci_utilities is
   IOR : String := PolyORB.Parameters.Get_Conf ("dsa", "name_service", "");
   IOR_File : File_Type;
begin
   configure_num_quartieri_name_server(3);
   configure_num_quartieri_synchronized_package(3);
   Put_Line(IOR);
   Create(File => IOR_File, Mode => Out_File, Name => "ior.txt");
   Put_Line(IOR_File, IOR);
   Close(IOR_File);
   Put_Line("rci utilities");
   loop
      delay 1.0;
   end loop;
   --Put_Line("end rci utilities");
end;
