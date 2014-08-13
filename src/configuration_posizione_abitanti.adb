with remote_types;
with global_data;

use remote_types;
use global_data;

package body configuration_posizione_abitanti is

   protected body posizione_abitanti_quartieri is

      procedure registra_gps_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti) is
      begin
         gps_abitanti_quartie(id_quartiere):= location_abitanti;
         num_quartieri:= num_quartieri+1;
      end registra_gps_abitanti_quartiere;

      entry wait_gps_abitanti_all_quaritieri(id_quartiere: Positive; gps_abitanti_quart: out gps_abitanti_quartieri) when num_quartieri=get_num_quartieri is
      begin
         gps_abitanti_quart:= gps_abitanti_quartie;
      end wait_gps_abitanti_all_quaritieri;

   end posizione_abitanti_quartieri;


end configuration_posizione_abitanti;
