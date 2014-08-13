with remote_types;
with global_data;

use remote_types;
use global_data;

package configuration_posizione_abitanti is

   protected type posizione_abitanti_quartieri is new rt_posizione_abitanti_quartieri with

        procedure registra_gps_abitanti_quartiere(id_quartiere: Positive; location_abitanti: ptr_rt_location_abitanti);
        entry wait_gps_abitanti_all_quaritieri(id_quartiere: Positive; gps_abitanti_quart: out gps_abitanti_quartieri);
   private
      gps_abitanti_quartie: gps_abitanti_quartieri(1..get_num_quartieri);
      num_quartieri: Natural:= 0;
   end posizione_abitanti_quartieri;

   type ptr_posizione_abitanti_quartieri is access posizione_abitanti_quartieri;

end configuration_posizione_abitanti;
