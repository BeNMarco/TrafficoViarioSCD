with GNATCOLL.JSON;
with Ada.Text_IO;

with remote_types;
with strade_e_incroci_common;
with JSON_Helper;
with data_quartiere;
with global_data;

use GNATCOLL.JSON;
use Ada.Text_IO;

use strade_e_incroci_common;
use remote_types;
use JSON_Helper;
use data_quartiere;
use global_data;

package body risorse_mappa_utilities is

   function create_array_urbane(json_roads: JSON_array; from: Natural; to: Natural) return strade_urbane_features is
      array_roads: strade_urbane_features(from..to);
      val_tipo: type_strade;
      val_id: Positive;
      val_id_quartiere: Positive;
      val_lunghezza: Float;
      val_num_corsie: Positive;
      strada: JSON_Value;
   begin
      for index_strada in from..to
      loop
         strada:= Get(Arr => json_roads,Index => index_strada-from+1);
         val_tipo:= urbana;
         val_id:= index_strada;--Get(Val => strada, Field => "id");
         val_id_quartiere:= get_id_quartiere;  -- TO DO
         val_lunghezza:= Get(Val => strada, Field => "lunghezza");
         val_num_corsie:= Get(Val => strada, Field => "numcorsie");
         array_roads(index_strada):= create_new_urbana(val_tipo => val_tipo,val_id => val_id,
                                                       val_id_quartiere => val_id_quartiere,
                                                       val_lunghezza => Float(val_lunghezza),
                                                       val_num_corsie => val_num_corsie);
      end loop;
      return array_roads;
   end create_array_urbane;

   function create_array_ingressi(json_roads: JSON_array; from: Natural; to: Natural) return strade_ingresso_features is
      array_roads: strade_ingresso_features(from..to);
      val_tipo: type_strade;
      val_id: Positive;
      val_id_quartiere: Positive;
      val_lunghezza: Float;
      val_num_corsie: Positive;
      val_id_main_strada : Positive;
      val_distance_from_road_head : Float;
      strada: JSON_Value;
   begin
      for index_strada in from..to
      loop
         strada:= Get(Arr => json_roads,Index => index_strada-from+1);
         val_tipo:= urbana;
         val_id:= index_strada;--Get(Val => strada, Field => "id");
         val_id_quartiere:= get_id_quartiere;  -- TO DO
         val_lunghezza:= Get(Val => strada, Field => "lunghezza");
         val_num_corsie:= Get(Val => strada, Field => "numcorsie");
         val_id_main_strada:= Get(Val => strada, Field => "strada_confinante")+get_from_urbane-1;
         val_distance_from_road_head:= Get(Val => strada, Field => "distanza_da_from");
         array_roads(index_strada):= create_new_ingresso(val_tipo => val_tipo,val_id => val_id,
                                                         val_id_quartiere => val_id_quartiere,
                                                         val_lunghezza => Float(val_lunghezza),
                                                         val_num_corsie => val_num_corsie,
                                                         val_id_main_strada => val_id_main_strada,
                                                         val_distance_from_road_head => val_distance_from_road_head);
      end loop;
      return array_roads;
   end create_array_ingressi;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4 is
      incroci: list_incroci_a_4(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_polo: Boolean;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         json_strade_incrocio:= Get(Val => json_strade_incrocio, Field => "strade");
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..4
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            val_polo:= Get(Val => json_strada, Field => "polo");
            val_id_strada:= val_id_strada + get_from_urbane - 1;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_polo);
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
      val_polo: Boolean;
      val_mancante: Positive;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         val_mancante:= Get(Val => json_strade_incrocio, Field => "strada_mancante")+1;
         json_strade_incrocio:= Get(Val => json_strade_incrocio, Field => "strade");
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..3
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            val_polo:= Get(Val => json_strada, Field => "polo");
            val_id_strada:= val_id_strada + get_from_urbane - 1;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_polo);
         end loop;
         indici_strada_mancanti(incrocio):= val_mancante;
      end loop;
      return incroci;
   end create_array_incroci_a_3;

   function create_array_rotonde_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4 is
      incroci: list_incroci_a_4(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_polo: Boolean;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         json_strade_incrocio:= Get(Val => json_strade_incrocio, Field => "strade");
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..4
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            val_polo:= Get(Val => json_strada, Field => "polo");
            val_id_strada:= val_id_strada + get_from_urbane - 1;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_polo);
         end loop;
      end loop;
      return incroci;
   end create_array_rotonde_a_4;

   function create_array_rotonde_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3 is
      incroci: list_incroci_a_3(from..to);
      json_strade_incrocio: JSON_Value;
      json_array_strade_incrocio: JSON_Array;
      json_strada: JSON_Value;
      val_id_quartiere: Positive;
      val_id_strada: Positive;
      val_polo: Boolean;
   begin
      for incrocio in from..to
      loop
         json_strade_incrocio:= Get(Arr => json_incroci,Index => incrocio-from+1);
         json_strade_incrocio:= Get(Val => json_strade_incrocio, Field => "strade");
         json_array_strade_incrocio:= Get(Val => json_strade_incrocio);
         for strada in 1..3
         loop
            json_strada:= Get(Arr => json_array_strade_incrocio,Index => strada);
	    val_id_quartiere:= Get(Val => json_strada, Field => "quartiere");
            val_id_strada:= Get(Val => json_strada, Field => "id_strada");
            val_polo:= Get(Val => json_strada, Field => "polo");
            val_id_strada:= val_id_strada + get_from_urbane - 1;
            incroci(incrocio)(strada):= create_new_road_incrocio(val_id_quartiere,val_id_strada,val_polo);
         end loop;
      end loop;
      return incroci;
   end create_array_rotonde_a_3;

   function get_mancante_incrocio_a_3(id_incrocio: Positive) return Positive is
   begin
      return indici_strada_mancanti(id_incrocio);
   end get_mancante_incrocio_a_3;

   procedure print_percorso(route: percorso) is
   begin
      Put("[");
      for i in route'Range loop
         Put_Line("(" & Integer'Image(route(i).get_id_quartiere_tratto) & "," & Integer'Image(route(i).get_id_tratto) & ")");
      end loop;
      Put("]");
   end print_percorso;

end risorse_mappa_utilities;
