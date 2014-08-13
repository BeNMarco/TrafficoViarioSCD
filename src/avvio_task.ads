with data_quartiere;
with risorse_strade_e_incroci;

use data_quartiere;
use risorse_strade_e_incroci;

package avvio_task is

private
   task_urbane: task_container_urbane(get_from_urbane..get_to_urbane);
   task_ingressi: task_container_ingressi(get_from_ingressi..get_to_ingressi);
   task_incroci: task_container_incroci(get_from_incroci_a_4..get_to_incroci_a_3);
   task_rotonde: task_container_rotonde(get_from_rotonde_a_4..get_to_rotonde_a_3);
end avvio_task;
