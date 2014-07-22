with rt_strade;

use rt_strade;

package rt_strade.strade_features is

   type strada_urbana_features is new rt_strada_features with private;

   type ptr_strada_urbana_features is access all strada_urbana_features;

   type strade_urbane_features is array(Positive range <>) of ptr_strada_urbana_features;

   type ptr_strade_urbane_features is access all strade_urbane_features;

   type strada_ingresso_features is new rt_strada_features with private;

   protected type resource_segmento_strada is new rt_segmento with
      procedure prova;
   private
     l: Positive:=1;
   end resource_segmento_strada;

   type ptr_resource_segmento_strada is access all resource_segmento_strada;

   function create_new_urbana(val_tipo: type_strade;val_id: Positive;val_id_quartiere: Positive;
                                val_lunghezza: Natural;val_num_corsie: Positive;
                                val_ptr_resource_strada: ptr_rt_segmento) return ptr_strada_urbana_features;

private

   type strada_urbana_features is new rt_strada_features with null record;

   type strada_ingresso_features is new rt_strada_features with record
      ptr_main_strada : access strada_urbana_features; -- strada principale dalla quale si ha la strada d'ingresso,
      						    -- si tratta sempre di una strada locale e non remota
      distance_from_road_head : Natural; -- distanza dalle coordinate from della strada principale
   end record;



end rt_strade.strade_features;
