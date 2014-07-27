with GNATCOLL.JSON;
with Ada.Text_IO;

with remote_types;
with strade_e_incroci_common;
with risorse_strade_e_incroci;
with JSON_Helper;

use GNATCOLL.JSON;
use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;
use risorse_strade_e_incroci;
use JSON_Helper;

package body partition_setup_utilities is

   function create_array_urbane(json_roads: JSON_array; from: Positive; to: Positive) return strade_urbane_features is
      array_roads: strade_urbane_features(from..to);
      ptr_resource_roads: ptr_resource_segmenti_strade:= new resource_segmenti_strade(from..to);
      val_tipo: type_strade;
      val_id: Positive;
      val_id_quartiere: Positive;
      val_lunghezza: Natural;
      val_num_corsie: Positive;
      val_ptr_resource_strada: ptr_resource_segmento_strada;
      strada: JSON_Value;
   begin
      for index_strada in from..to
      loop
         strada:= Get(Arr => json_roads,Index => index_strada-from+1);
         val_tipo:= urbana;
         val_id:= index_strada;--Get(Val => strada, Field => "id");
         val_id_quartiere:= 1;  -- TO DO
         val_lunghezza:= Get(Val => strada, Field => "lunghezza");
         val_num_corsie:= Get(Val => strada, Field => "numcorsie");
         val_ptr_resource_strada:= new resource_segmento_strada;
         array_roads(index_strada):= create_new_urbana(val_tipo => val_tipo,val_id => val_id,
                                                       val_id_quartiere => val_id_quartiere,
                                                       val_lunghezza => val_lunghezza,
                                                       val_num_corsie => val_num_corsie);
         ptr_resource_roads.all(index_strada):= val_ptr_resource_strada;
      end loop;
      urbane_segmento_resources:= ptr_resource_roads;
      return array_roads;
   end create_array_urbane;

   function create_array_ingressi(json_roads: JSON_array; from: Positive; to: Positive) return strade_ingresso_features is
      array_roads: strade_ingresso_features(from..to);
      ptr_resource_roads: ptr_resource_segmenti_strade:= new resource_segmenti_strade(from..to);
      val_tipo: type_strade;
      val_id: Positive;
      val_id_quartiere: Positive;
      val_lunghezza: Natural;
      val_num_corsie: Positive;
      val_ptr_resource_strada: ptr_resource_segmento_strada;
      val_id_main_strada : Positive;
      val_distance_from_road_head : Natural;
      strada: JSON_Value;
   begin
      for index_strada in from..to
      loop
         strada:= Get(Arr => json_roads,Index => index_strada-from+1);
         val_tipo:= urbana;
         val_id:= index_strada;--Get(Val => strada, Field => "id");
         val_id_quartiere:= 1;  -- TO DO
         val_lunghezza:= Get(Val => strada, Field => "lunghezza");
         val_num_corsie:= Get(Val => strada, Field => "numcorsie");
         val_id_main_strada:= Get(Val => strada, Field => "strada_confinante");
         val_distance_from_road_head:= Get(Val => strada, Field => "distanza_da_from");
         val_ptr_resource_strada:= new resource_segmento_strada;
         array_roads(index_strada):= create_new_ingresso(val_tipo => val_tipo,val_id => val_id,
                                                               val_id_quartiere => val_id_quartiere,
                                                               val_lunghezza => val_lunghezza,
                                                               val_num_corsie => val_num_corsie,
                                                               val_id_main_strada => val_id_main_strada,
                                                               val_distance_from_road_head => val_distance_from_road_head);
         ptr_resource_roads.all(index_strada):= val_ptr_resource_strada;
      end loop;
      ingressi_segmento_resources:= ptr_resource_roads;
      return array_roads;
   end create_array_ingressi;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural;
                                     from_urbane: Positive; from_ingressi: Positive) return list_incroci_a_4 is
      incroci: list_incroci_a_4(from..to);
      ptr_resource_roads: ptr_resource_segmenti_strade:= new resource_segmenti_strade(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_ptr_resource_strada: ptr_resource_segmento_strada;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..4
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "id_quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            val_id_strada:= val_id_strada + from_urbane - 1;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada);
         end loop;
         val_ptr_resource_strada:= new resource_segmento_strada;
         ptr_resource_roads.all(incrocio):= val_ptr_resource_strada;
      end loop;
      return incroci;
   end create_array_incroci_a_4;

   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural;
                                     from_urbane: Positive; from_ingressi: Positive) return list_incroci_a_3 is
      incroci: list_incroci_a_3(from..to);
      ptr_resource_roads: ptr_resource_segmenti_strade:= new resource_segmenti_strade(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_ptr_resource_strada: ptr_resource_segmento_strada;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..3
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "id_quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            val_id_strada:= val_id_strada + from_urbane - 1;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada);
         end loop;
         val_ptr_resource_strada:= new resource_segmento_strada;
         ptr_resource_roads.all(incrocio):= val_ptr_resource_strada;
      end loop;
      return incroci;
   end create_array_incroci_a_3;

end partition_setup_utilities;
