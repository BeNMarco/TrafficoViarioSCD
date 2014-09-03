with data_quartiere;
with strade_e_incroci_common;
with remote_types;
with global_data;
with the_name_server;
with risorse_mappa_utilities;
with synchronization_task_partition;
with mailbox_risorse_attive;
with handle_semafori;

use data_quartiere;
use strade_e_incroci_common;
use remote_types;
use global_data;
use the_name_server;
use risorse_mappa_utilities;
use synchronization_task_partition;
use mailbox_risorse_attive;
use handle_semafori;

package resource_map_inventory is

   function get_synchronization_tasks_partition_object return ptr_synchronization_tasks;

   protected type wait_all_quartieri is new rt_wait_all_quartieri with
      procedure all_quartieri_set;
      entry wait_quartieri;
   private
      segnale: Boolean:= False;
   end wait_all_quartieri;

   type ptr_wait_all_quartieri is access wait_all_quartieri;

   procedure wait_settings_all_quartieri;

   type ptr_route_and_distance is access all route_and_distance'Class;
   type percorso_abitanti is array(Positive range <>) of ptr_route_and_distance;

   protected type location_abitanti(num_abitanti: Positive) is new rt_location_abitanti with
        procedure set_percorso_abitante(id_abitante: Positive; percorso: route_and_distance);
   private
      percorsi: percorso_abitanti(1..num_abitanti):= (others => null);
   end location_abitanti;

   type ptr_location_abitanti is access location_abitanti;

   function get_locate_abitanti_quartiere return ptr_location_abitanti;

   protected type quartiere_utilities is new rt_quartiere_utilities with
      procedure registra_classe_locate_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti);
      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                  bici: list_bici_quartiere; auto: list_auto_quartiere);
      procedure registra_mappa(id_quartiere: Positive);
      function get_abitante_quartiere(id_quartiere: Positive; id_abitante: Positive) return abitante;
      function get_pedone_quartiere(id_quartiere: Positive; id_abitante: Positive) return pedone;
      function get_bici_quartiere(id_quartiere: Positive; id_abitante: Positive) return bici;
      function get_auto_quartiere(id_quartiere: Positive; id_abitante: Positive) return auto;
   private

      entità_abitanti: list_abitanti_quartieri(1..get_num_quartieri);
      entità_pedoni: list_pedoni_quartieri(1..get_num_quartieri);
      entità_bici: list_bici_quartieri(1..get_num_quartieri);
      entità_auto: list_auto_quartieri(1..get_num_quartieri);

      -- array i quali oggetti sono del tipo ptr_rt_location_abitanti per ottenere le informazioni esposte sopra per gps_abitanti
      rt_classi_locate_abitanti: gps_abitanti_quartieri(1..get_num_quartieri);

   end quartiere_utilities;

   type ptr_quartiere_utilities is access all quartiere_utilities;

   function get_quartiere_utilities_obj return ptr_quartiere_utilities;

   type ptr_strade_urbane_features is access all strade_urbane_features;

   function get_urbana_from_id(index: Positive) return strada_urbana_features;
   function get_ingresso_from_id(index: Positive) return strada_ingresso_features;
   function get_incrocio_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_incrocio_a_3_from_id(index: Positive) return list_road_incrocio_a_3;
   function get_rotonda_a_4_from_id(index: Positive) return list_road_incrocio_a_4;
   function get_rotonda_a_3_from_id(index: Positive) return list_road_incrocio_a_3;

   type estremi_strada_urbana is array(Positive range 1..2) of ptr_rt_segmento;
   function get_estremi_urbana(id_urbana: Positive) return estremi_strada_urbana;

private

   quartiere_cfg: ptr_quartiere_utilities:= new quartiere_utilities;
   waiting_object: ptr_wait_all_quartieri:= new wait_all_quartieri;

   protected waiting_cfg is
      procedure incrementa_classi_locate_abitanti;
      procedure incrementa_num_quartieri_abitanti;
      procedure incrementa_resource_mappa_quartieri;
      entry wait_cfg;
   private
      num_classi_locate_abitanti: Natural:= 0;
      num_abitanti_quartieri_registrati: Natural:= 0;
      num_quartieri_resource_registrate: Natural:= 0;
      inventory_estremi_is_set: Boolean:= False;
   end waiting_cfg;

   urbane_features: strade_urbane_features:= create_array_urbane(json_roads => get_json_urbane, from => get_from_urbane, to => get_to_urbane);
   ingressi_features: strade_ingresso_features:= create_array_ingressi(json_roads => get_json_ingressi, from => get_from_ingressi, to => get_to_ingressi);
   incroci_a_4: list_incroci_a_4:= create_array_incroci_a_4(json_incroci => get_json_incroci_a_4, from => get_from_incroci_a_4, to => get_to_incroci_a_4);
   incroci_a_3: list_incroci_a_3:= create_array_incroci_a_3(json_incroci => get_json_incroci_a_3, from => get_from_incroci_a_3, to => get_to_incroci_a_3);
   rotonde_a_4: list_incroci_a_4:= create_array_rotonde_a_4(json_incroci => get_json_rotonde_a_4, from => get_from_rotonde_a_4, to => get_to_rotonde_a_4);
   rotonde_a_3: list_incroci_a_3:= create_array_rotonde_a_3(json_incroci => get_json_rotonde_a_3, from => get_from_rotonde_a_3, to => get_to_rotonde_a_3);

   traiettorie_incroci: traiettorie_incrocio:= create_traiettorie_incrocio(json_traiettorie => get_json_traiettorie_incrocio);
   traiettorie_ingressi: traiettorie_ingresso:= create_traiettorie_ingresso(json_traiettorie => get_json_traiettorie_ingresso);
   -- classe utilizzata per settare la posizione corrente di un abitante, per settare il percorso, per ottenere il percorso
   locate_abitanti_quartiere: ptr_location_abitanti:= new location_abitanti(get_to_abitanti-get_from_abitanti+1);

   -- server gps
   gps: ptr_gps_interface:= get_server_gps;

   synchronization_tasks_partition: ptr_synchronization_tasks:= new synchronization_tasks;

   semafori_quartiere_obj: ptr_handler_semafori_quartiere:= new handler_semafori_quartiere;

   inventory_estremi: estremi_urbane(get_from_urbane..get_to_urbane,1..2):= (others => (others => null));

end resource_map_inventory;
