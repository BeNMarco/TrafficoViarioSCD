with strade_common;
with rt_strade;

use strade_common;
use rt_strade;

package strade_common.strade_features is

   -- begin urbane
   type strada_urbana_features is new rt_strada_features with private;
   --type ptr_strada_urbana_features is access all strada_urbana_features;
   type strade_urbane_features is array(Positive range <>) of strada_urbana_features;
   type ptr_strade_urbane_features is access all strade_urbane_features;
   -- end urbane

   -- begin ingressi
   type strada_ingresso_features is new rt_strada_features with private;
   --type ptr_strada_ingresso_features is access all strada_ingresso_features;
   type strade_ingresso_features is array(Positive range <>) of strada_ingresso_features;
   type ptr_strade_ingresso_features is access all strade_ingresso_features;
   --end ingressi

   -- begin incroci
   type list_incroci_a_4 is array(Positive range <>) of list_road_incrocio_a_4;
   type list_incroci_a_3 is array(Positive range <>) of list_road_incrocio_a_3;
   type list_incroci_a_2 is array(Positive range <>) of list_road_incrocio_a_2;
   -- end incroci

   -- begin risorse
   type ptr_rt_segmento is access all rt_segmento;
   protected type resource_segmento_strada is new rt_segmento with
      procedure prova;
   private
     l: Positive:=1;
   end resource_segmento_strada;
   type ptr_resource_segmento_strada is access all resource_segmento_strada;
   type resource_segmenti_strade is array(Positive range <>) of ptr_resource_segmento_strada;
   type ptr_resource_segmenti_strade is access all resource_segmenti_strade;
   -- end risorse

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                              val_lunghezza: Natural;val_num_corsie: Positive) return strada_urbana_features;

   function create_new_ingresso(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: Natural;val_num_corsie: Positive;val_id_main_strada: Positive;
                                val_distance_from_road_head: Natural) return strada_ingresso_features;

private

   type strada_urbana_features is new rt_strada_features with null record;

   type strada_ingresso_features is new rt_strada_features with record
      id_main_strada : Positive; 	-- strada principale dalla quale si ha la strada d'ingresso
      					-- si tratta sempre di una strada locale e non remota
      distance_from_road_head : Natural; -- distanza dalle coordinate from della strada principale
   end record;

end strade_common.strade_features;
