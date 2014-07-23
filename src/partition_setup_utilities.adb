with GNATCOLL.JSON;
with Ada.Text_IO;

with rt_strade;
with strade_common;
with strade_common.strade_features;
with JSON_Helper;

use GNATCOLL.JSON;
use Ada.Text_IO;

use strade_common;
use rt_strade;
use strade_common.strade_features;
use JSON_Helper;

package body partition_setup_utilities is

   function create_array_strade(json_roads: JSON_array) return strade_urbane_features is
      array_roads: strade_urbane_features(1..Length(json_roads));
      ptr_resource_roads: ptr_resource_segmenti_strade:= new resource_segmenti_strade(1..Length(json_roads));
      val_tipo: type_strade;
      val_id: Positive;
      val_id_quartiere: Positive;
      val_lunghezza: Natural;
      val_num_corsie: Positive;
      val_ptr_resource_strada: ptr_resource_segmento_strada;
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
         val_ptr_resource_strada:= new resource_segmento_strada;
         array_roads(index_strada):= create_new_urbana(val_tipo => val_tipo,val_id => val_id,
                                                       val_id_quartiere => val_id_quartiere,
                                                       val_lunghezza => val_lunghezza,
                                                       val_num_corsie => val_num_corsie);
         ptr_resource_roads.all(index_strada):= val_ptr_resource_strada;
      end loop;
      urbane_segmento_resources:= ptr_resource_roads;
      return array_roads;
   end create_array_strade;

   function create_array_ingressi(json_roads: JSON_array) return strade_ingresso_features is
      array_roads: strade_ingresso_features(1..Length(json_roads));
      ptr_resource_roads: ptr_resource_segmenti_strade:= new resource_segmenti_strade(1..Length(json_roads));
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
      for index_strada in 1..Length(json_roads)
      loop
         strada:= Get(Arr => json_roads,Index => index_strada);
         val_tipo:= urbana;
         val_id:= Get(Val => strada, Field => "id");
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

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4 is
      incroci: list_incroci_a_4(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_tipo_strada: type_strade;
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
            if Get(Get(Val => json_strada, Field => "tipo_strada"))="urbana" then
               val_tipo_strada:= urbana;
            else
               val_tipo_strada:= ingresso;
            end if;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_tipo_strada);
         end loop;
      end loop;
      return incroci;
   end create_array_incroci_a_4;

   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3 is
      incroci: list_incroci_a_3(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_tipo_strada: type_strade;
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
            if Get(Get(Val => json_strada, Field => "tipo_strada"))="urbana" then
               val_tipo_strada:= urbana;
            else
               val_tipo_strada:= ingresso;
            end if;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_tipo_strada);
         end loop;
      end loop;
      return incroci;
   end create_array_incroci_a_3;

   function create_array_incroci_a_2(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_2 is
      incroci: list_incroci_a_2(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_tipo_strada: type_strade;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..2
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "id_quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            if Get(Get(Val => json_strada, Field => "tipo_strada"))="urbana" then
               val_tipo_strada:= urbana;
            else
               val_tipo_strada:= ingresso;
            end if;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_tipo_strada);
         end loop;
      end loop;
      return incroci;
   end create_array_incroci_a_2;

end partition_setup_utilities;
