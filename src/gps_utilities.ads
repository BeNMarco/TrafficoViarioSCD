with strade_e_incroci_common;
with remote_types;
with data_quartiere;
with global_data;

use strade_e_incroci_common;
use remote_types;
use data_quartiere;
use global_data;

package gps_utilities is

   type index_incroci is tagged private;
   type estremi_incrocio is array(Positive range 1..2) of index_incroci;
   type hash_quartiere_strade is array(Positive range <>) of estremi_incrocio;
   type hash_quartieri_strade is array(Positive range <>) of access hash_quartiere_strade;

   type adiacente is tagged private;
   -- begin get methods adiacente
   function get_id_quartiere_strada(near: adiacente) return Natural;
   function get_id_strada(near: adiacente) return Natural;
   function get_id_quartiere_adiacente(near: adiacente) return Natural;
   function get_id_adiacente(near: adiacente) return Natural;
   -- end get methods adiacente
   type list_adiacenti is array(Positive range 1..4) of adiacente;
   type nodi_quartiere is array(Positive range <>) of list_adiacenti;
   type grafo_mappa is array(Positive range <>) of access nodi_quartiere;

   -- begin strutture per il calcolo del percorso
   type index_to_consider is array(Positive range <>) of index_incroci;
   type dijkstra_nodo is record
      precedente: index_incroci; -- se 0 dopo l'algoritmo => è il nodo sorgente
      distanza: Natural:= Natural'Last;
      id_quartiere_spigolo: Natural:= 0;
      id_spigolo: Natural:= 0;
      in_coda: Boolean:= False;
   end record;
   type dijkstra_nodi is array(Positive range <>,Positive range <>) of  dijkstra_nodo;
   -- end strutture per il calcolo del percorso

   type list_percorso is private;
   type ptr_percorso is access list_percorso;

   function create_new_index_incrocio(val_id_quartiere: Natural; val_id_incrocio: Natural; val_polo: Boolean) return index_incroci;

   function create_new_adiacente(val_id_quartiere_strada: Natural; val_id_strada: Natural;
                                 val_id_quartiere_adiacente: Natural; val_id_adiacente: Natural) return adiacente;

   -- begin get methods index_incrocio
   function get_id_quartiere_index_incroci(incrocio: index_incroci) return Natural;
   function get_id_incrocio_index_incroci(incrocio: index_incroci) return Natural;
   function get_polo_index_incroci(incrocio: index_incroci) return Boolean;
   -- end get methods index_incrocio



   protected type registro_strade_resource is new gps_interface with
      procedure registra_urbane_quartiere(id_quartiere: Positive; urbane: strade_urbane_features);
      procedure registra_ingressi_quartiere(id_quartiere: Positive; ingressi: strade_ingresso_features);
      entry registra_incroci_quartiere(id_quartiere: Positive; incroci_a_4: list_incroci_a_4;
                                       incroci_a_3: list_incroci_a_3; rotonde_a_4: list_incroci_a_4;
                                       rotonde_a_3: list_incroci_a_3);
      function calcola_percorso(from_id_quartiere: Positive; from_id_luogo: Positive;
                                to_id_quartiere: Positive; to_id_luogo: Positive) return route_and_distance;
   private

      function create_array_percorso(size: Natural; route: ptr_percorso) return percorso;
      procedure print_grafo;

      cache_urbane: urbane_quartiere(1..get_num_quartieri);
      cache_ingressi: ingressi_quartiere(1..get_num_quartieri);
      hash_urbane_quartieri: hash_quartieri_strade(1..get_num_quartieri);
      grafo: grafo_mappa(1..get_num_quartieri);
      num_urbane_quartieri_registrate: Natural:= 0;
      num_incroci_quartieri_registrati: Natural:= 0;
      min_first_incroci: Natural:= 0;
      max_last_incroci: Natural:= 0;
      numero_globale_incroci: Natural:= 0;
   end registro_strade_resource;

   type ptr_registro_strade_resource is access all registro_strade_resource;

   function create_list_percorso(segmento: tratto; next_percorso: ptr_percorso) return ptr_percorso;

private

   type index_incroci is tagged record
      id_quartiere: Natural:= 0;
      id_incrocio: Natural:= 0;
      polo: Boolean;
   end record;

   type adiacente is tagged record
      id_quartiere_strada: Natural:= 0;    -- se id_quartiere_strada e/o id_strada sono 0 significa che
      id_strada: Natural:= 0;		   -- non esiste l'adiacente;
      id_quartiere_adiacente: Natural:= 0; -- !!!!!! id_quartiere_adiacente e id_adiacente possono essere entrambi 0
      id_adiacente: Natural:= 0;           -- ma id_quartiere_strada e id_strada diversi da 0 sse la strada è una
   end record;				   -- strada chiusa.

   type list_percorso is record
      segmento: tratto;
      next: ptr_percorso:= null;
   end record;

end gps_utilities;
