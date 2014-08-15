--pragma Priority_Specific_Dispatching(Round_Robin_Within_Priorities,1,10);
-- NOTA: avvio_task.ads fa partire i task; risorse_strade_e_incroci.initiliaze.ads configura i task precedentemente
--       avviati => risorse_strade_e_incroci.initiliaze dipende da avvio_task; risorse_strade_e_incroci.initiliaze deve seguire avvio_task
--       nella lista delle dipendenze.

with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with strade_e_incroci_common;
with the_name_server;
with remote_types;
with risorse_strade_e_incroci.initiliaze;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use the_name_server;
use remote_types;

procedure main is


   --gps: ptr_gps_interface;
   --percor: access route_and_distance;
begin
   --gps:= get_server_gps;
   --gps.registra_urbane_quartiere(1, urbane_features);
   --gps.registra_ingressi_quartiere(1,ingressi_features);
   --gps.registra_incroci_quartiere(1,incroci_a_4,incroci_a_3,rotonde_a_4,rotonde_a_3);
   --percor:= new route_and_distance'(gps.calcola_percorso(1,7,1,8));
   --print_percorso(percor.get_percorso_from_route_and_distance);
   null;
end main;
