with GNATCOLL.JSON;
with Ada.Text_IO;

with rt_strade;
with rt_strade.strade_features;
with JSON_Helper;

use GNATCOLL.JSON;
use Ada.Text_IO;

use rt_strade;
use rt_strade.strade_features;
use JSON_Helper;

package body partition_setup_utilities is

   function create_array_strade(json_roads: JSON_array) return ptr_strade_urbane_features is
      ptr_array_roads: ptr_strade_urbane_features:=new strade_urbane_features(1..json_roads'Size);
      val_tipo: type_strade;
      val_id: Positive;
      val_id_quartiere: Positive;
      val_lunghezza: Natural;
      val_num_corsie: Positive;
      val_ptr_resource_strada: ptr_rt_segmento;
      ptr_segmento_strada: ptr_resource_segmento_strada;
      strada: JSON_Value;
   begin
      for index_strada in 1..Length(json_roads)
      loop
         strada:= Get(Arr => json_roads,Index => index_strada);
         val_tipo:= urbana;
         val_id:= Get(Val => strada, Field => "id");
         val_id_quartiere:= 1;  -- TO DO
         val_lunghezza:= Get(Val => strada, Field => "lunghezza");
         val_num_corsie:= Get(Val => strada, Field => "numcorsie");
         ptr_segmento_strada:= new resource_segmento_strada;
         val_ptr_resource_strada:= ptr_rt_segmento(ptr_segmento_strada);
         ptr_array_roads.all(index_strada):= create_new_urbana(val_tipo => val_tipo,val_id => val_id,
                                                               val_id_quartiere => val_id_quartiere,
                                                               val_lunghezza => val_lunghezza,
                                                               val_num_corsie => val_num_corsie,
                                                               val_ptr_resource_strada => val_ptr_resource_strada);
      end loop;
      return ptr_array_roads;
   end create_array_strade;

end partition_setup_utilities;
