with data_quartiere;
with risorse_strade_e_incroci;

use data_quartiere;
use risorse_strade_e_incroci;

package avvio_task is
private
   task_urbane: task_container_urbane(from_urbane..to_urbane);
   task_ingressi: task_container_ingressi(from_ingressi..to_ingressi);
   task_incroci: task_container_incroci(from_incroci_a_4..to_incroci_a_3);
   task_rotonde: task_container_rotonde(from_rotonde_a_4..to_rotonde_a_3);
end avvio_task;
