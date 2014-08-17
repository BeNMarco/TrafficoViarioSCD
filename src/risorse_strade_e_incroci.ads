with remote_types;
with data_quartiere;
with strade_e_incroci_common;
with global_data;
with the_name_server;
with risorse_mappa_utilities;

use remote_types;
use data_quartiere;
use strade_e_incroci_common;
use global_data;
use the_name_server;
use risorse_mappa_utilities;

package risorse_strade_e_incroci is

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;

   protected type location_abitanti(num_abitanti: Positive) is new rt_location_abitanti with
        procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
   private
      percorsi: percorso_abitanti(1..num_abitanti):= (others => null);
   end location_abitanti;

   type ptr_location_abitanti is access location_abitanti;

   type core_avanzamento is limited interface;

   procedure configure(entity: access core_avanzamento; id: Positive; resource: ptr_resource_segmento_strada) is abstract;

   task type core_avanzamento_urbane is new core_avanzamento with
      entry configure(id: Positive; resource: ptr_resource_segmento_strada);
   end core_avanzamento_urbane;

   type task_container_urbane is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_ingressi is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_rotonde is array(Positive range <>) of core_avanzamento_urbane;
   type task_container_incroci is array(Positive range <>) of core_avanzamento_urbane;

   procedure configure_tasks;

private

   task_urbane: task_container_urbane(get_from_urbane..get_to_urbane);
   task_ingressi: task_container_ingressi(get_from_ingressi..get_to_ingressi);
   task_incroci: task_container_incroci(get_from_incroci_a_4..get_to_incroci_a_3);
   task_rotonde: task_container_rotonde(get_from_rotonde_a_4..get_to_rotonde_a_3);

end risorse_strade_e_incroci;
