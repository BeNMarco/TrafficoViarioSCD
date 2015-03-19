with Ada.Text_IO;

with global_data;
with remote_types;
with gps_utilities;
with the_name_server;

use Ada.Text_IO;

use remote_types;
use gps_utilities;
use the_name_server;
use global_data;


package body configuration_server_parameter is

   procedure registra_server_utilities is
   begin
      registra_server_gps(ptr_gps_interface(gps));
      registra_synchronization_tasks_object(ptr_rt_task_synchronization(synchronization_task_obj));
   end;

end configuration_server_parameter;
