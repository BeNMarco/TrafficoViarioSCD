with global_data;
with remote_types;
with gps_utilities;
with the_name_server;
with synchronized_task_partitions;

use remote_types;
use gps_utilities;
use the_name_server;
use global_data;
use synchronized_task_partitions;

package configuration_server_parameter is

   procedure registra_server_utilities;

private
   gps: ptr_registro_strade_resource:= new registro_strade_resource(get_num_quartieri);
   synchronization_task_obj: ptr_task_synchronization:= new task_synchronization(get_num_quartieri);
end configuration_server_parameter;
