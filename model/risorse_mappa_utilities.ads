with GNATCOLL.JSON;

with strade_e_incroci_common;
with data_quartiere;
with remote_types;
with numerical_types;

use GNATCOLL.JSON;

use strade_e_incroci_common;
use data_quartiere;
use remote_types;
use numerical_types;

package risorse_mappa_utilities is

   type intersezione_incrocio is tagged private;
   type intersezioni_incrocio is array(Positive range <>) of intersezione_incrocio;
   type ptr_intersezioni_incrocio is access intersezioni_incrocio;
   type traiettoria_incrocio is tagged private;
   type traiettorie_incrocio is array(traiettoria_incroci_type range traiettoria_incroci_type'First..traiettoria_incroci_type'Last) of traiettoria_incrocio;

   type intersezione_linee is tagged private;
   type intersezioni_linee is array(Positive range <>) of intersezione_linee;
   type ptr_intersezioni_linee is access intersezioni_linee;

   type intersezione_ingresso is tagged private;
   type intersezioni_ingresso is array(Positive range <>) of intersezione_ingresso;
   type ptr_intersezioni_ingresso is access intersezioni_ingresso;
   type traiettoria_ingresso is tagged private;
   type traiettorie_ingresso is array(traiettoria_ingressi_type range traiettoria_ingressi_type'First..traiettoria_ingressi_type'Last) of traiettoria_ingresso;

   type traiettoria_cambio_corsia is tagged private;

   function create_array_abitanti_in_bus return set;

   function create_array_urbane(json_roads: JSON_array; from: Natural; to: Natural) return strade_urbane_features;

   function create_array_ingressi(json_roads: JSON_array; from: Natural; to: Natural) return strade_ingresso_features;

   function create_array_incroci_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_incroci_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;
   -- nel JSON la numerazione delle mancanti parte da 0; qui si fa partire da 1 quindi viene messo +1. DA SISTEMARE

   function create_array_rotonde_a_4(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_4;

   function create_array_rotonde_a_3(json_incroci: JSON_array; from: Natural; to: Natural) return list_incroci_a_3;

   function create_traiettorie_incrocio(json_traiettorie: JSON_Value) return traiettorie_incrocio;

   function create_traiettoria_incrocio(lunghezza: Float; corsia_arrivo: id_corsie; corsia_partenza: id_corsie;
                                        intersezioni: ptr_intersezioni_incrocio;
                                        intersezioni_corsie: ptr_intersezioni_linee; intersezione_bipede: Float) return traiettoria_incrocio;

   function create_intersezione_incrocio(traiettoria: traiettoria_incroci_type; distanza: Float) return intersezione_incrocio;

   function create_intersezione_linea(traiettoria: traiettorie_intersezioni_linee_corsie; distanza: Float) return intersezione_linee;

   function create_intersezione_ingresso(traiettoria: traiettoria_ingressi_type; distanza: Float) return intersezione_ingresso;

   function create_traiettoria_ingresso(lunghezza: Float; intersezioni: ptr_intersezioni_ingresso; intersezioni_corsie: ptr_intersezioni_linee; intersezione_bipedi: Float) return traiettoria_ingresso;

   function create_traiettorie_ingresso(json_traiettorie: JSON_Value) return traiettorie_ingresso;

   function create_traiettoria_cambio_corsia(json_traiettorie: JSON_Value) return traiettoria_cambio_corsia;

   procedure print_percorso(route: percorso);

   type list_mancanti_incroci_a_3 is array(Positive range <>) of Positive;

   function get_mancante_incrocio_a_3(id_incrocio: Positive) return Natural;

   function get_lunghezza(obj: traiettoria_ingresso) return new_float;
   function get_intersezioni(obj: traiettoria_ingresso) return intersezione_ingresso'Class;
   function get_intersezioni_corsie(obj: traiettoria_ingresso; linea: traiettorie_intersezioni_linee_corsie) return intersezione_linee'Class;
   function get_intersezione_bipedi(obj: traiettoria_ingresso) return new_float;
   function get_traiettoria_intersezione(obj: intersezione_ingresso) return traiettoria_ingressi_type;
   function get_distanza_intersezione(obj: intersezione_ingresso) return new_float;

   function get_traiettoria_intersezioni_corsie(obj: intersezione_linee) return traiettorie_intersezioni_linee_corsie;
   function get_distanza_intersezioni_corsie(obj: intersezione_linee) return new_float;

   function get_lunghezza_traiettoria(obj: traiettoria_cambio_corsia) return new_float;
   function get_lunghezza_lineare_traiettoria(obj: traiettoria_cambio_corsia) return new_float;
   function get_distanza_intersezione_linea_di_mezzo(obj: traiettoria_cambio_corsia) return new_float;

   function get_lunghezza_traiettoria_incrocio(obj: traiettoria_incrocio) return new_float;
   function get_intersezioni_incrocio(obj: traiettoria_incrocio; con_traiettoria: traiettoria_incroci_type) return intersezione_incrocio'Class;
   function get_intersezioni_corsie(obj: traiettoria_incrocio; linea: traiettorie_intersezioni_linee_corsie) return intersezione_linee'Class;
   function get_intersezione_bipedi(obj: traiettoria_incrocio) return new_float;

   function get_traiettoria_intersezione_incrocio(obj: intersezione_incrocio) return traiettoria_incroci_type;
   function get_distanza_intersezione_incrocio(obj: intersezione_incrocio) return new_float;

private

   indici_strada_mancanti: list_mancanti_incroci_a_3(get_from_incroci_a_3..get_to_incroci_a_3);

   type intersezione_incrocio is tagged record
      traiettoria: traiettoria_incroci_type;
      distanza: new_float;
   end record;

   type intersezione_linee is tagged record
      traiettoria: traiettorie_intersezioni_linee_corsie;
      distanza: new_float;
   end record;

   type traiettoria_incrocio is tagged record
      lunghezza: new_float;
      corsia_arrivo: id_corsie;
      corsia_partenza: id_corsie;
      intersezioni: ptr_intersezioni_incrocio;
      intersezioni_corsie: ptr_intersezioni_linee;
      intersezione_bipede: new_float;
   end record;

   type intersezione_ingresso is tagged record
      traiettoria: traiettoria_ingressi_type;
      distanza: new_float;
   end record;

   type traiettoria_ingresso is tagged record
      lunghezza: new_float;
      intersezioni: ptr_intersezioni_ingresso;
      intersezioni_corsie: ptr_intersezioni_linee;
      intersezione_bipedi: new_float;
   end record;

   type traiettoria_cambio_corsia is tagged record
      lunghezza_traiettoria: new_float;
      lunghezza_lineare: new_float;
      distanza_intersezione_linea_di_mezzo: new_float;
   end record;

end risorse_mappa_utilities;
