--pragma Priority_Specific_Dispatching(Round_Robin_Within_Priorities,1,10);
--pragma Priority_Specific_Dispatching(FIFO_Within_Priorities,1,10);
with GNATCOLL.JSON;
with Ada.Text_IO;

with handle_semafori;
with JSON_Helper;
with strade_e_incroci_common;
with the_name_server;
with remote_types;
with resource_map_inventory;
with risorse_strade_e_incroci;
with start_simulation;
with data_quartiere;
with risorse_mappa_utilities;
with mailbox_risorse_attive;
with risorse_passive_data;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use the_name_server;
use remote_types;
use resource_map_inventory;
use risorse_strade_e_incroci;
use start_simulation;
use data_quartiere;
use risorse_mappa_utilities;
use mailbox_risorse_attive;
use risorse_passive_data;

procedure quartiere_2 is

begin
   registra_quartiere_entities_life(get_id_quartiere,ptr_rt_quartiere_entities_life(get_quartiere_entities_life_obj));
   start_entity_to_move;
end quartiere_2;
