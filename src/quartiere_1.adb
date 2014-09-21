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

procedure quartiere_1 is

   gps: ptr_gps_interface;
   percor: access route_and_distance;
begin
   gps:= get_server_gps;
   --gps.registra_urbane_quartiere(1, urbane_features);
   --gps.registra_ingressi_quartiere(1,ingressi_features);
   --gps.registra_incroci_quartiere(1,incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3);
   --percor:= new route_and_distance'(gps.calcola_percorso(1,5,1,6));
   --print_percorso(percor.get_percorso_from_route_and_distance);
   percor:= new route_and_distance'(gps.calcola_percorso(1,1,1,3));
   print_percorso(percor.get_percorso_from_route_and_distance);
   percor:= new route_and_distance'(gps.calcola_percorso(1,1,2,2));
   print_percorso(percor.get_percorso_from_route_and_distance);

   if get_id_quartiere=1 then
      get_quartiere_utilities_obj.get_classe_locate_abitanti(1).set_percorso_abitante(get_from_abitanti,gps.calcola_percorso(1,1,2,2));
      get_ingressi_segmento_resources(35).new_abitante_to_move(1,get_from_abitanti,car);
      --get_ingressi_segmento_resources(35).new_abitante_to_move(1,get_from_abitanti+1,car);
   end if;


   null;
end quartiere_1;
