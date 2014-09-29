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
      val_polo: Boolean;
      strada: JSON_Value;
   begin
      for index_strada in from..to
      loop
         strada:= Get(Arr => json_roads,Index => index_strada-from+1);
         val_tipo:= ingresso;
         val_id:= index_strada;--Get(Val => strada, Field => "id");
         val_id_quartiere:= get_id_quartiere;  -- TO DO
         val_lunghezza:= Get(Val => strada, Field => "lunghezza");
         val_num_corsie:= Get(Val => strada, Field => "numcorsie");
         val_id_main_strada:= Get(Val => strada, Field => "strada_confinante")+get_from_urbane-1;
         val_distance_from_road_head:= Get(Val => strada, Field => "distanza_da_from");
         val_polo:= Get(Val => strada, Field => "polo");
         array_roads(index_strada):= create_new_ingresso(val_tipo => val_tipo,val_id => val_id,
                                                         val_id_quartiere => val_id_quartiere,
                                                         val_lunghezza => Float(val_lunghezza),
                                                         val_num_corsie => val_num_corsie,
                                                         val_id_main_strada => val_id_main_strada,
                                                         val_distance_from_road_head => val_distance_from_road_head,
                                                         polo => val_polo);
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

   function create_intersezione_ingresso(traiettoria: traiettoria_ingressi_type; distanza: Float) return intersezione_ingresso is
      intersezione: intersezione_ingresso;
   begin
      intersezione.traiettoria:= traiettoria;
      intersezione.distanza:= distanza;
      return intersezione;
   end create_intersezione_ingresso;

   function create_traiettoria_ingresso(lunghezza: Float; intersezioni: ptr_intersezioni_ingresso; intersezioni_corsie: ptr_intersezioni_linee) return traiettoria_ingresso is
      traiettoria: traiettoria_ingresso;
   begin
      traiettoria.lunghezza:= lunghezza;
      traiettoria.intersezioni:= null;
      traiettoria.intersezioni_corsie:= intersezioni_corsie;
      return traiettoria;
   end create_traiettoria_ingresso;

   function create_traiettorie_ingresso(json_traiettorie: JSON_Value) return traiettorie_ingresso is
      traiettorie: traiettorie_ingresso;
      traiettoria_entrata_andata: JSON_Value;
      traiettoria_uscita_andata: JSON_Value;
      traiettoria_entrata_ritorno: JSON_Value;
      traiettoria_uscita_ritorno: JSON_Value;
      intersezioni: JSON_Array;
      intersezione: JSON_Value;
      array_intersezioni: ptr_intersezioni_ingresso:= null;
      array_intersezioni_corsie: ptr_intersezioni_linee:= null;
   begin
      traiettoria_entrata_andata:= Get(Val => json_traiettorie, Field => "entrata_andata");
      traiettoria_uscita_andata:= Get(Val => json_traiettorie, Field => "uscita_andata");
      traiettoria_entrata_ritorno:= Get(Val => json_traiettorie, Field => "entrata_ritorno");
      traiettoria_uscita_ritorno:= Get(Val => json_traiettorie, Field => "uscita_ritorno");

      traiettorie(entrata_andata):= create_traiettoria_ingresso(Get(Val => traiettoria_entrata_andata, Field => "lunghezza"),null,null);

      traiettorie(uscita_andata):= create_traiettoria_ingresso(Get(Val => traiettoria_uscita_andata, Field => "lunghezza"),null,null);

      intersezioni:= Get(Val => traiettoria_entrata_ritorno, Field => "intersezioni");
      array_intersezioni:= new intersezioni_ingresso(1..1);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni(1):= create_intersezione_ingresso(uscita_ritorno,Get(Val => intersezione, Field => "distanza"));
      intersezioni:= Get(Val => traiettoria_entrata_ritorno, Field => "intersezioni_corsie");
      array_intersezioni_corsie:= new intersezioni_linee(1..2);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni_corsie(1):= create_intersezione_linea(linea_corsia,Get(Val => intersezione, Field => "distanza"));
      intersezione:= Get(Arr => intersezioni,Index => 2);
      array_intersezioni_corsie(2):= create_intersezione_linea(linea_mezzaria,Get(Val => intersezione, Field => "distanza"));
      traiettorie(entrata_ritorno):= create_traiettoria_ingresso(Get(Val => traiettoria_entrata_ritorno, Field => "lunghezza"),
                                                                 array_intersezioni,array_intersezioni_corsie);

      intersezioni:= Get(Val => traiettoria_uscita_ritorno, Field => "intersezioni");
      array_intersezioni:= new intersezioni_ingresso(1..1);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni(1):= create_intersezione_ingresso(entrata_ritorno,Get(Val => intersezione, Field => "distanza"));
      intersezioni:= Get(Val => traiettoria_uscita_ritorno, Field => "intersezioni_corsie");
      array_intersezioni_corsie:= new intersezioni_linee(1..2);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni_corsie(1):= create_intersezione_linea(linea_corsia,Get(Val => intersezione, Field => "distanza"));
      intersezione:= Get(Arr => intersezioni,Index => 2);
      array_intersezioni_corsie(2):= create_intersezione_linea(linea_mezzaria,Get(Val => intersezione, Field => "distanza"));
      traiettorie(uscita_ritorno):= create_traiettoria_ingresso(Get(Val => traiettoria_uscita_ritorno, Field => "lunghezza"),
                                                                array_intersezioni,array_intersezioni_corsie);

      return traiettorie;
   end create_traiettorie_ingresso;

   function create_traiettoria_cambio_corsia(json_traiettorie: JSON_Value) return traiettoria_cambio_corsia is
      traiettoria: traiettoria_cambio_corsia;
   begin
      traiettoria.lunghezza_traiettoria:= Get(Val => json_traiettorie, Field => "lunghezza_traiettoria");
      traiettoria.distanza_intersezione_linea_di_mezzo:= Get(Val => json_traiettorie, Field => "distanza_intersezione_linea_di_mezzo");
      traiettoria.lunghezza_lineare:= Get(Val => json_traiettorie, Field => "lunghezza_lineare");
      return traiettoria;
   end create_traiettoria_cambio_corsia;

   function create_traiettorie_incrocio(json_traiettorie: JSON_Value) return traiettorie_incrocio is
      traiettorie: traiettorie_incrocio;
      traiettoria_destra: JSON_Value;
      traiettoria_sinistra: JSON_Value;
      traiettoria_dritto_1: JSON_Value;
      traiettoria_dritto_2: JSON_Value;
      strada_partenza: JSON_Value;
      strada_arrivo: JSON_Value;
      intersezioni: JSON_Array;
      intersezione: JSON_Value;
      array_intersezioni: ptr_intersezioni_incrocio:= null;
      array_intersezioni_corsie: ptr_intersezioni_linee:= null;
   begin
      traiettoria_destra:= Get(Val => json_traiettorie, Field => "destra");
      traiettoria_sinistra:= Get(Val => json_traiettorie, Field => "sinistra");
      traiettoria_dritto_1:= Get(Val => json_traiettorie, Field => "dritto_1");
      traiettoria_dritto_2:= Get(Val => json_traiettorie, Field => "dritto_2");

      strada_partenza:= Get(Val => traiettoria_destra, Field => "strada_partenza");
      strada_arrivo:= Get(Val => traiettoria_destra, Field => "strada_arrivo");
      traiettorie(destra):= create_traiettoria_incrocio(Get(Val => traiettoria_destra, Field => "lunghezza"),
                                                        Get(Val => strada_partenza, Field => "corsia"),
                                                        Get(Val => strada_arrivo, Field => "corsia"),
                                                        null,null);

      strada_partenza:= Get(Val => traiettoria_sinistra, Field => "strada_partenza");
      strada_arrivo:= Get(Val => traiettoria_sinistra, Field => "strada_arrivo");
      intersezioni:= Get(Val => traiettoria_sinistra, Field => "intersezioni");
      array_intersezioni:= new intersezioni_incrocio(1..2);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni(1):= create_intersezione_incrocio(dritto_1,Get(Val => intersezione, Field => "distanza"));
      intersezione:= Get(Arr => intersezioni,Index => 2);
      array_intersezioni(2):= create_intersezione_incrocio(dritto_2,Get(Val => intersezione, Field => "distanza"));
      intersezioni:= Get(Val => traiettoria_sinistra, Field => "intersezioni_corsie");
      array_intersezioni_corsie:= new intersezioni_linee(1..2);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni_corsie(1):= create_intersezione_linea(linea_corsia,Get(Val => intersezione, Field => "distanza"));
      intersezione:= Get(Arr => intersezioni,Index => 2);
      array_intersezioni_corsie(2):= create_intersezione_linea(linea_mezzaria,Get(Val => intersezione, Field => "distanza"));
      traiettorie(sinistra):= create_traiettoria_incrocio(Get(Val => traiettoria_sinistra, Field => "lunghezza"),
                                                          Get(Val => strada_partenza, Field => "corsia"),
                                                          Get(Val => strada_arrivo, Field => "corsia"),
                                                          array_intersezioni,
                                                          array_intersezioni_corsie);

      strada_partenza:= Get(Val => traiettoria_dritto_1, Field => "strada_partenza");
      strada_arrivo:= Get(Val => traiettoria_dritto_1, Field => "strada_arrivo");
      intersezioni:= Get(Val => traiettoria_dritto_1, Field => "intersezioni");
      array_intersezioni:= new intersezioni_incrocio(1..1);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni(1):= create_intersezione_incrocio(sinistra,Get(Val => intersezione, Field => "distanza"));
      traiettorie(dritto_1):= create_traiettoria_incrocio(Get(Val => traiettoria_dritto_1, Field => "lunghezza"),
                                                          Get(Val => strada_partenza, Field => "corsia"),
                                                          Get(Val => strada_arrivo, Field => "corsia"),
                                                          array_intersezioni,null);

      strada_partenza:= Get(Val => traiettoria_dritto_2, Field => "strada_partenza");
      strada_arrivo:= Get(Val => traiettoria_dritto_2, Field => "strada_arrivo");
      intersezioni:= Get(Val => traiettoria_dritto_2, Field => "intersezioni");
      array_intersezioni:= new intersezioni_incrocio(1..1);
      intersezione:= Get(Arr => intersezioni,Index => 1);
      array_intersezioni(1):= create_intersezione_incrocio(sinistra,Get(Val => intersezione, Field => "distanza"));
      traiettorie(dritto_2):= create_traiettoria_incrocio(Get(Val => traiettoria_dritto_2, Field => "lunghezza"),
                                                          Get(Val => strada_partenza, Field => "corsia"),
                                                          Get(Val => strada_arrivo, Field => "corsia"),
                                                          array_intersezioni,null);

      return traiettorie;

   end create_traiettorie_incrocio;

   function get_mancante_incrocio_a_3(id_incrocio: Positive) return Natural is
   begin
      if id_incrocio>=get_from_incroci_a_3 and id_incrocio<=get_to_incroci_a_3 then
         return indici_strada_mancanti(id_incrocio);
      else
         return 0;
      end if;
   end get_mancante_incrocio_a_3;

   function create_traiettoria_incrocio(lunghezza: Float; corsia_arrivo: id_corsie; corsia_partenza: id_corsie;
                                        intersezioni: ptr_intersezioni_incrocio; intersezioni_corsie: ptr_intersezioni_linee) return traiettoria_incrocio is
      traiettoria: traiettoria_incrocio;
   begin
      traiettoria.lunghezza:= lunghezza;
      traiettoria.corsia_arrivo:= corsia_arrivo;
      traiettoria.corsia_partenza:= corsia_partenza;
      traiettoria.intersezioni:= intersezioni;
      traiettoria.intersezioni_corsie:= intersezioni_corsie;
      return traiettoria;
   end create_traiettoria_incrocio;

   function create_intersezione_incrocio(traiettoria: traiettoria_incroci_type; distanza: Float) return intersezione_incrocio is
      intersezione: intersezione_incrocio;
   begin
      intersezione.traiettoria:= traiettoria;
      intersezione.distanza:= distanza;
      return intersezione;
   end create_intersezione_incrocio;

   function create_intersezione_linea(traiettoria: traiettorie_intersezioni_linee_corsie; distanza: Float) return intersezione_linee is
      intersezione: intersezione_linee;
   begin
      intersezione.traiettoria:= traiettoria;
      intersezione.distanza:= distanza;
      return intersezione;
   end create_intersezione_linea;

   function get_lunghezza(obj: traiettoria_ingresso) return Float is
   begin
      return obj.lunghezza;
   end get_lunghezza;
   function get_intersezioni(obj: traiettoria_ingresso) return ptr_intersezioni_ingresso is
   begin
      return obj.intersezioni;
   end get_intersezioni;
   function get_intersezioni_corsie(obj: traiettoria_ingresso; linea: traiettorie_intersezioni_linee_corsie) return intersezione_linee'Class is
   begin
      case linea is
         when linea_corsia =>
            return intersezione_linee(obj.intersezioni_corsie.all(1));
         when linea_mezzaria =>
            return intersezione_linee(obj.intersezioni_corsie.all(2));
      end case;
   end get_intersezioni_corsie;
   function get_traiettoria_intersezione(obj: intersezione_ingresso) return traiettoria_ingressi_type is
   begin
      return obj.traiettoria;
   end get_traiettoria_intersezione;
   function get_distanza_intersezione(obj: intersezione_ingresso) return Float is
   begin
      return obj.distanza;
   end get_distanza_intersezione;

   function get_traiettoria_intersezioni_corsie(obj: intersezione_linee) return traiettorie_intersezioni_linee_corsie is
   begin
      return obj.traiettoria;
   end get_traiettoria_intersezioni_corsie;
   function get_distanza_intersezioni_corsie(obj: intersezione_linee) return Float is
   begin
      return obj.distanza;
   end get_distanza_intersezioni_corsie;

   function get_lunghezza_traiettoria(obj: traiettoria_cambio_corsia) return Float is
   begin
      return obj.lunghezza_traiettoria;
   end get_lunghezza_traiettoria;
   function get_lunghezza_lineare_traiettoria(obj: traiettoria_cambio_corsia) return Float is
   begin
      return obj.lunghezza_lineare;
   end get_lunghezza_lineare_traiettoria;
   function get_distanza_intersezione_linea_di_mezzo(obj: traiettoria_cambio_corsia) return Float is
   begin
      return obj.distanza_intersezione_linea_di_mezzo;
   end get_distanza_intersezione_linea_di_mezzo;

   function get_lunghezza_traiettoria_incrocio(obj: traiettoria_incrocio) return Float is
   begin
      return obj.lunghezza;
   end get_lunghezza_traiettoria_incrocio;
   function get_intersezioni_incrocio(obj: traiettoria_incrocio; con_traiettoria: traiettoria_incroci_type) return intersezione_incrocio'Class is
   begin
      case con_traiettoria is
         when empty | dritto | destra =>
            return create_intersezione_incrocio(empty,0.0);
         when sinistra =>
            return obj.intersezioni(1);
         when dritto_1 =>
            return obj.intersezioni(1);
         when dritto_2 =>
            return obj.intersezioni(2);
      end case;
   end get_intersezioni_incrocio;

   function get_intersezioni_corsie(obj: traiettoria_incrocio; linea: traiettorie_intersezioni_linee_corsie) return intersezione_linee'Class is
   begin
      case linea is
         when linea_corsia =>
            return intersezione_linee(obj.intersezioni_corsie.all(1));
         when linea_mezzaria =>
            return intersezione_linee(obj.intersezioni_corsie.all(2));
      end case;
   end get_intersezioni_corsie;

   function get_traiettoria_intersezione_incrocio(obj: intersezione_incrocio) return traiettoria_incroci_type is
   begin
      return obj.traiettoria;
   end get_traiettoria_intersezione_incrocio;
   function get_distanza_intersezione_incrocio(obj: intersezione_incrocio) return Float is
   begin
      return obj.distanza;
   end get_distanza_intersezione_incrocio;

   procedure print_percorso(route: percorso) is
   begin
      Put("[");
      for i in route'Range loop
         Put_Line("(" & Integer'Image(route(i).get_id_quartiere_tratto) & "," & Integer'Image(route(i).get_id_tratto) & ")");
      end loop;
      Put("]");
   end print_percorso;

end risorse_mappa_utilities;
